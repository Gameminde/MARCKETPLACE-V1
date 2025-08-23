console.log('Script d\'import des templates');
const mongoose = require('mongoose');
const Template = require('../models/Template');
require('dotenv').config();
console.log('Démarrage import des templates...');
const { templatesData } = require('../data/templates-data');
console.log('Nombre de templates à importer:', templatesData.length);
