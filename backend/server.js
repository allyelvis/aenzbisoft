const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(cors());
const productRoutes = require('./routes/productRoutes');
app.use(express.json());
app.use('/api/products', productRoutes);

mongoose.connect('mongodb://localhost/AenzbiSoft', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});

const port = process.env.PORT || 5000;
app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
