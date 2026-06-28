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

    // Delete all doctors except the main one: Dr. manirul hussain (ID: 8082ca85-d363-4feb-a7a6-debc93abb166)
    const result = await doctorsCollection.deleteMany({
      id: { $ne: '8082ca85-d363-4feb-a7a6-debc93abb166' }
    });
    console.log(`Deleted ${result.deletedCount} duplicate/placeholder doctor records.`);

    const remaining = await doctorsCollection.find({}).toArray();
    console.log('Remaining doctors in database:');
    remaining.forEach((doc, idx) => {
      console.log(`[${idx}] ID: ${doc.id}, Name: ${doc.name}, UserID: ${doc.user_id}, Specialization: ${doc.specialization}`);
    });

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.close();
  }
}

run();
