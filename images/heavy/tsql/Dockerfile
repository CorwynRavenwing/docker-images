# images/heavy/tsql/Dockerfile

FROM mcr.microsoft.com/mssql/server:2022-latest

# Accept EULA and set SA password (must meet complexity requirements)
ENV ACCEPT_EULA=Y \
    MSSQL_SA_PASSWORD=App_Secret123! \
    MSSQL_PID=Express

# Expose default MS SQL port
EXPOSE 1433

