# Django 專案

## 環境設定

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## 程式碼慣例

- 所有 Python 程式碼遵循 PEP 8
- 使用 `black` 自動格式化
- 使用 `isort` 排序 import

## 測試

```bash
python manage.py test          # 執行所有測試
pytest --cov=. --cov-report=html  # 含覆蓋率
```

## 資料庫

- 一律使用 Django ORM — 應用程式碼中不可出現 raw SQL
- 所有 schema 變更都透過 migration：`python manage.py makemigrations`
- migration 檔案 commit 之後絕不手動編輯

## API

使用 Django REST Framework。所有 endpoint 都必須用 `drf-spectacular` 撰寫文件。
