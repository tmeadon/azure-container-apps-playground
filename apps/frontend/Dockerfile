FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build

WORKDIR /app

COPY frontend.csproj .

RUN dotnet restore

COPY . .

RUN dotnet publish --no-restore -c Release -o ./publish

FROM  mcr.microsoft.com/dotnet/sdk:5.0 AS final

WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT [ "dotnet", "frontend.dll" ]