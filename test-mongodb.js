const mongoose = require('mongoose');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://cvhoai_db_user:Ry5Z62YUprIYexWp@qrcodesdc.emvwzan.mongodb.net/qrmanager?retryWrites=true&w=majority&appName=qrcodesdc';

console.log('Testing MongoDB connection...');
console.log('URI:', MONGODB_URI.replace(/:[^:@]+@/, ':****@')); // Hide password

mongoose.connect(MONGODB_URI)
    .then(() => {
        console.log('✅ MongoDB connection successful!');
        console.log('Database:', mongoose.connection.db.databaseName);
        process.exit(0);
    })
    .catch(err => {
        console.error('❌ MongoDB connection failed:');
        console.error(err.message);
        process.exit(1);
    });

