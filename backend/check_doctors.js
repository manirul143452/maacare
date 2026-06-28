const { MongoClient } = require('mongodb');
require('dotenv').config();

const uri = process.env.MONGO_URI || "mongodb+srv://hussainmanirul9_db_user:qHGxKrTbHdR16Jj1@cluster0.hyxqfxb.mongodb.net/maacare?retryWrites=true&w=majority&appName=Cluster0";

async function run() {
  const client = new MongoClient(uri);
  try {
    await client.connect();
    console.log('Connected to MongoDB.');
    const db = client.db();
    const doctorsCollection = db.collection('doctors');

    const doctors = await doctorsCollection.find({}).toArray();
    console.log(`Found ${doctors.length} doctors:`);
    doctors.forEach((doc, idx) => {
      console.log(`[${idx}] ID: ${doc.id || doc._id}, _id: ${doc._id}, Name: ${doc.name}, UserID: ${doc.user_id}, Specialization: ${doc.specialization}, Email: ${doc.email}`);
    });
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.close();
  }
}

run();
