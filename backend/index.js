const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Configuración de CORS para que Flutter Web pueda conectarse
app.use(cors());
app.use(express.json());

// Configuración de la conexión a PostgreSQL
// Usa los datos que encontré en tu DatabaseService de Flutter
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false // Requerido para Supabase/Render
  }
});

// Probar conexión a la DB
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Error conectando a Postgres:', err);
  } else {
    console.log('Conexión a Postgres exitosa en:', res.rows[0].now);
  }
});

// --- MIDDLEWARE DE SEGURIDAD ---

// Middleware para verificar el token JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Acceso denegado: Token no proporcionado' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'sistemacorrespondencia', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Token inválido o expirado' });
    }
    req.user = user;
    next();
  });
};

// --- ENDPOINTS ---

// Endpoint de Login
app.post('/api/auth/login', async (req, res) => {
  const { usuario, password } = req.body;
  try {
    // Buscar usuario con JOIN para obtener nombres de rol y sucursal
    const sql = `
      SELECT u.id, u.username, u.nombre_completo, u.password_hash, 
             r.nombre as rol_nombre, s.nombre as sucursal_nombre, u.sucursal_id
      FROM usuarios u
      JOIN roles r ON u.role_id = r.id
      JOIN sucursales s ON u.sucursal_id = s.id
      WHERE u.username = $1 AND u.activo = true
    `;
    const result = await pool.query(sql, [usuario]);
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Usuario no encontrado o inactivo' });
    }

    const user = result.rows[0];
    
    // Verificar contraseña (soporta texto plano para admin inicial y bcrypt)
    let validPassword = false;
    if (user.password_hash === password) {
      validPassword = true;
    } else {
      try {
        validPassword = await bcrypt.compare(password, user.password_hash);
      } catch (e) {
        validPassword = false;
      }
    }
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Contraseña incorrecta' });
    }

    // Generar un token JWT
    const token = jwt.sign(
      { 
        id: user.id, 
        username: user.username, 
        role: user.rol_nombre,
        sucursal_id: user.sucursal_id 
      }, 
      process.env.JWT_SECRET || 'sistemacorrespondencia', 
      { expiresIn: '8h' }
    );

    res.json({ 
      token, 
      user: { 
        id: user.id, 
        username: user.username,
        nombre_completo: user.nombre_completo,
        rol_nombre: user.rol_nombre,
        sucursal_nombre: user.sucursal_nombre,
        sucursal_id: user.sucursal_id
      } 
    });
  } catch (err) {
    console.error('Error en login:', err);
    res.status(500).json({ error: 'Error en el servidor' });
  }
});

// Endpoint genérico para ejecutar consultas (Protegido por JWT)
app.post('/api/query', authenticateToken, async (req, res) => {
  const { sql, params } = req.body;
  try {
    // IMPORTANTE: En producción, deberíamos restringir qué tipo de consultas se pueden hacer aquí.
    // Opcional: Podrías forzar que el id_sucursal de la consulta coincida con el del token si es necesario.
    const result = await pool.query(sql, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Error ejecutando query:', err.message);
    res.status(500).json({ error: 'Error en la consulta de base de datos' });
  }
});

app.listen(port, () => {
  console.log(`API de Correspondencia corriendo en http://localhost:${port}`);
});
