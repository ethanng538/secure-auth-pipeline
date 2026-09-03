const express = require('express');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const app = express();

app.disable('x-powered-by');

app.use(express.json());


/**
 * Manages internal routing connections to the back-end database service.
 * @type {Pool}
 */
const pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 5432,
});

/**
 * Validates network connectivity and server availability.
 * @param {express.Request} req The incoming Express request object.
 * @param {express.Response} res The outgoing Express response object.
 */
app.get('/health', (req, res) => {
    res.status(200).json({status: 'healthy'});
});

/**
 * Registers a new user account.
 * This function ingests input parameters to insert a new user row into the database.
 * @param {express.Request} req Expects username and password in body.
 * @param {express.Response} res Returns status message or systemic database error.
 */
app.post('/api/register', async (req, res) => {
    const { username, password } = req.body;
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const queryText = 'INSERT INTO users(username, password) VALUES($1, $2) RETURNING id';
        const queryValues = [username, hashedPassword];

        const result = await pool.query(queryText, queryValues);

        res.status(201).json({message: 'User registered.', id: result.rows[0].id});
    } catch (error) {
        res.status(500).json({error: error.message});
    }
});

/**
 * Authenticates user credentials.
 * This function matches incoming username and password inputs against saved database rows.
 * @param {express.Request} req Expects username and password in body.
 * @param {express.Response} res Returns success confirmation or access denial.
 */
app.post('/api/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        const queryText = 'SELECT * FROM users WHERE username = $1';
        const queryValues = [username];

        const result = await pool.query(queryText, queryValues);

        if (result.rows.length === 0) {
            return res.status(401).json({error: 'Login failed'});
        }

        const userRow = result.rows[0];
        const isMatch = await bcrypt.compare(password, userRow.password);

        if (!isMatch) {
            return res.status(401).json({error: 'Login failed'});
        }

        res.status(200).json({message: 'Welcome'});
    } catch (error) {
        res.status(500).json({error: error.message});
    }
});

const PORT = 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});