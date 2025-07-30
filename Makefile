.PHONY: help install test lint format clean build docs

help:
	@echo "Available commands:"
	@echo "  make install    - Install all dependencies"
	@echo "  make test       - Run all tests"
	@echo "  make lint       - Run linting checks"
	@echo "  make format     - Format code with black"
	@echo "  make clean      - Clean temporary files"
	@echo "  make build      - Build distribution packages"
	@echo "  make docs       - Generate documentation"

install:
	pip install -r requirements.txt
	pip install -e .
	pre-commit install

test:
	pytest tests/ -v --cov=src --cov-report=html

lint:
	flake8 src/ tests/
	mypy src/
	black --check src/ tests/

format:
	black src/ tests/

clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf dist/ build/ .coverage htmlcov/ .pytest_cache/

build: clean
	python -m build

docs:
	@echo "Documentation generation not yet configured"