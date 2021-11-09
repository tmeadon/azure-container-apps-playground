FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build

WORKDIR /app

COPY . .

RUN dotnet publish -c Release -o ./publish

FROM  mcr.microsoft.com/dotnet/sdk:5.0 AS final

WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT [ "dotnet", "worker.dll" ]