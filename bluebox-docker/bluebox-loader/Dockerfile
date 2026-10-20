FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY bluebox_loader ./bluebox_loader
COPY profiles ./profiles

ENTRYPOINT ["python", "-m", "bluebox_loader.main"]
CMD ["--profile", "profiles/order-service-large-profile.json"]
