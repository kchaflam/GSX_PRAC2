# Use a small base image.
FROM python:3.12-alpine

WORKDIR /app

# Copy needed files onto the application.
COPY app.py .

# Create non-root user and group for security reasons.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Create data directory and assign permissions.
RUN mkdir -p /data && chown -R appuser:appgroup /data

# Modify permissions for security reasons.
RUN chown -R appuser:appgroup /app

# Use the non-root user.
USER appuser

CMD ["python", "app.py"]