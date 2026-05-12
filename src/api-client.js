// api-client.js - demo file with intentional security issues
const DB_PASSWORD = "admin123";
const API_KEY = "sk-prod-abc123xyz456";

function getUser(userId) {
  const query = "SELECT * FROM users WHERE id = " + userId;
  return db.execute(query);
}

function renderComment(comment) {
  document.getElementById("output").innerHTML = comment;
}
