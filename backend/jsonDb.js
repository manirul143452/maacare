const fs = require('fs');
const path = require('path');

const DB_DIR = path.join(__dirname, 'data', 'db_collections');

// Ensure DB directory exists
if (!fs.existsSync(DB_DIR)) {
  fs.mkdirSync(DB_DIR, { recursive: true });
}

function getCollectionPath(tableName) {
  return path.join(DB_DIR, `${tableName}.json`);
}

function readCollection(tableName) {
  const filePath = getCollectionPath(tableName);
  if (!fs.existsSync(filePath)) {
    return [];
  }
  try {
    const data = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(data || '[]');
  } catch (err) {
    console.error(`Error reading collection ${tableName}:`, err);
    return [];
  }
}

function writeCollection(tableName, data) {
  const filePath = getCollectionPath(tableName);
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
  } catch (err) {
    console.error(`Error writing collection ${tableName}:`, err);
  }
}

function matches(doc, query) {
  for (const [key, val] of Object.entries(query)) {
    if (key === '$or') {
      if (!Array.isArray(val)) return false;
      const matchedAny = val.some(subQuery => matches(doc, subQuery));
      if (!matchedAny) return false;
    } else {
      if (doc[key] !== val) {
        return false;
      }
    }
  }
  return true;
}

class JsonCursor {
  constructor(docs) {
    this.docs = [...docs];
    this.sortObj = null;
    this.skipVal = 0;
    this.limitVal = null;
  }

  sort(sortObj) {
    this.sortObj = sortObj;
    return this;
  }

  skip(skipVal) {
    this.skipVal = skipVal;
    return this;
  }

  limit(limitVal) {
    this.limitVal = limitVal;
    return this;
  }

  async toArray() {
    let results = [...this.docs];

    // Apply sorting
    if (this.sortObj) {
      const entries = Object.entries(this.sortObj);
      if (entries.length > 0) {
        const [field, dir] = entries[0]; // Sort by first key
        results.sort((a, b) => {
          const valA = a[field];
          const valB = b[field];
          if (valA === undefined) return 1;
          if (valB === undefined) return -1;
          if (valA < valB) return dir === -1 ? 1 : -1;
          if (valA > valB) return dir === -1 ? -1 : 1;
          return 0;
        });
      }
    }

    // Apply skip
    if (this.skipVal > 0) {
      results = results.slice(this.skipVal);
    }

    // Apply limit
    if (this.limitVal !== null && this.limitVal >= 0) {
      results = results.slice(0, this.limitVal);
    }

    return results;
  }
}

class JsonCollection {
  constructor(tableName) {
    this.tableName = tableName;
  }

  async findOne(query) {
    const docs = readCollection(this.tableName);
    return docs.find(doc => matches(doc, query)) || null;
  }

  find(query) {
    const docs = readCollection(this.tableName);
    const filtered = docs.filter(doc => matches(doc, query));
    return new JsonCursor(filtered);
  }

  async insertOne(doc) {
    const docs = readCollection(this.tableName);
    docs.push(doc);
    writeCollection(this.tableName, docs);
    return { acknowledged: true, insertedId: doc._id || doc.id };
  }

  async insertMany(newDocs) {
    const docs = readCollection(this.tableName);
    docs.push(...newDocs);
    writeCollection(this.tableName, docs);
    return { acknowledged: true, insertedCount: newDocs.length };
  }

  async replaceOne(filter, replacement, options = {}) {
    const docs = readCollection(this.tableName);
    const idx = docs.findIndex(doc => matches(doc, filter));
    if (idx !== -1) {
      docs[idx] = replacement;
      writeCollection(this.tableName, docs);
      return { acknowledged: true, modifiedCount: 1, matchedCount: 1 };
    } else if (options.upsert) {
      docs.push(replacement);
      writeCollection(this.tableName, docs);
      return { acknowledged: true, modifiedCount: 0, matchedCount: 0, upsertedId: replacement._id || replacement.id };
    }
    return { acknowledged: true, modifiedCount: 0, matchedCount: 0 };
  }

  async updateOne(filter, updateObj) {
    const docs = readCollection(this.tableName);
    let modifiedCount = 0;
    const setObj = updateObj.$set || {};

    let updated = false;
    const updatedDocs = docs.map(doc => {
      if (!updated && matches(doc, filter)) {
        modifiedCount++;
        updated = true;
        return { ...doc, ...setObj };
      }
      return doc;
    });

    if (modifiedCount > 0) {
      writeCollection(this.tableName, updatedDocs);
    }
    return { acknowledged: true, modifiedCount, matchedCount: modifiedCount };
  }

  async updateMany(filter, updateObj) {
    const docs = readCollection(this.tableName);
    let modifiedCount = 0;
    const setObj = updateObj.$set || {};

    const updatedDocs = docs.map(doc => {
      if (matches(doc, filter)) {
        modifiedCount++;
        return { ...doc, ...setObj };
      }
      return doc;
    });

    if (modifiedCount > 0) {
      writeCollection(this.tableName, updatedDocs);
    }
    return { acknowledged: true, modifiedCount };
  }

  async deleteMany(filter) {
    const docs = readCollection(this.tableName);
    const beforeCount = docs.length;
    const filtered = docs.filter(doc => !matches(doc, filter));
    const deletedCount = beforeCount - filtered.length;

    if (deletedCount > 0) {
      writeCollection(this.tableName, filtered);
    }
    return { acknowledged: true, deletedCount };
  }
}

class JsonDb {
  collection(tableName) {
    return new JsonCollection(tableName);
  }
}

module.exports = {
  JsonDb
};
