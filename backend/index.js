const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Configuración de CORS segura
const allowedOrigins = [
  'https://sistemacorrespondencia-3fbba.web.app',
  'https://sistemacorrespondencia-3fbba.firebaseapp.com',
  'http://localhost:3000',
  'http://localhost:5000'
];

app.use(cors({
  origin: function (origin, callback) {
    // Permitir peticiones sin origen (como apps móviles nativas o herramientas de prueba)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) === -1) {
      return callback(new Error('Acceso bloqueado por política de CORS'), false);
    }
    return callback(null, true);
  }
}));
app.use(express.json());

// Configuración de la conexión a PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false // Permite conexiones SSL a Supabase/Render
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Probar conexión a la DB con log detallado
pool.connect((err, client, release) => {
  if (err) {
    console.error('[DATABASE] Error crítico de conexión:', err.stack);
  } else {
    console.log('[DATABASE] Conexión exitosa a Supabase desde el Backend');
    release();
  }
});

// --- ENDPOINTS ---

// Endpoint de Login con manejo de errores detallado
app.post('/api/auth/login', async (req, res) => {
  const { usuario, password } = req.body;
  
  if (!usuario || !password) {
    return res.status(400).json({ error: 'Usuario y contraseña son requeridos' });
  }

  try {
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
    const validPassword = await bcrypt.compare(password, user.password_hash);
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Contraseña incorrecta' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.rol_nombre, sucursal_id: user.sucursal_id }, 
      process.env.JWT_SECRET || 'sistemacorrespondencia', 
      { expiresIn: '8h' }
    );

    res.json({ 
      token, 
      user: { 
        id: user.id, username: user.username, nombre_completo: user.nombre_completo,
        rol_nombre: user.rol_nombre, sucursal_nombre: user.sucursal_nombre, sucursal_id: user.sucursal_id
      } 
    });
  } catch (err) {
    console.error('[AUTH ERROR]', err.message);
    res.status(500).json({ error: 'Error interno en el servidor de autenticación', detail: err.message });
  }
});

// Endpoint de consulta con try-catch global
app.post('/api/query', authenticateToken, async (req, res) => {
  const { sql, params } = req.body;
  try {
    const result = await pool.query(sql, params);
    res.json(result.rows);
  } catch (err) {
    console.error('[QUERY ERROR]', { sql, error: err.message });
    res.status(500).json({ 
      error: 'Error en la consulta de base de datos', 
      detail: err.message,
      hint: 'Asegúrate de haber ejecutado el script SQL de migración en Supabase'
    });
  }
});

app.listen(port, () => {
  console.log(`API de Correspondencia corriendo en http://localhost:${port}`);
});
