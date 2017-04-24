const fs = require('fs');
const path = require('path');
const express = require('express');
const learnJson = require('./learn.json');

const learner = require.resolve('./learn.json');

const app = express();
const dir = path.resolve(__dirname, '..');

app.use(express.static(dir));
app.use('/learn.json', express.static(learner));
app.use('/favicon.ico', function () {});

app.listen(8000);
