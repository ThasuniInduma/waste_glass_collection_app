FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY WasteGlassApi.csproj .
RUN dotnet restore WasteGlassApi.csproj
COPY . .
RUN dotnet publish WasteGlassApi.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_ENVIRONMENT=Production

# Railway assigns the listen port via $PORT at container start
ENTRYPOINT ["sh", "-c", "ASPNETCORE_URLS=http://0.0.0.0:${PORT:-8080} dotnet WasteGlassApi.dll"]
