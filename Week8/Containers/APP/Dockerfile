# Use a small base image.
FROM python:3.12-alpine

# Enviroment variables.
ENV PORT=8080

WORKDIR /app

# Copy needed files onto the application.
COPY app.py .

# Create non-root user and group for security reasons.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Modify permissions for security reasons.
RUN chown -R appuser:appgroup /app

# Use the non-root user.
USER appuser

# Use the only port needed for the service.
EXPOSE 8080

CMD ["python", "app.py"]