# Django Project

## Environment Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Code Conventions

- Follow PEP 8 for all Python code
- Use `black` for auto-formatting
- Use `isort` for import sorting

## Testing

```bash
python manage.py test          # run all tests
pytest --cov=. --cov-report=html  # with coverage
```

## Database

- Use Django ORM exclusively — no raw SQL in application code
- All schema changes via migrations: `python manage.py makemigrations`
- Never edit migration files manually after they are committed

## API

Use Django REST Framework. All endpoints must be documented with `drf-spectacular`.
