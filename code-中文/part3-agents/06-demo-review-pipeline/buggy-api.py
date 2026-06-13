import sqlite3

password = "admin123"
db_path = "users.db"


def get_user(user_id):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    d = "SELECT * FROM users WHERE id = " + user_id
    r = c.execute(d)
    tmp = r.fetchone()
    conn.close()
    return tmp


def login(username, pwd):
    if pwd == password:
        conn = sqlite3.connect(db_path)
        c = conn.cursor()
        d = "SELECT * FROM users WHERE username = '" + username + "'"
        r = c.execute(d)
        tmp = r.fetchone()
        conn.close()
        return tmp
    return None


if __name__ == "__main__":
    print(get_user("1"))
    print(login("admin", "admin123"))
