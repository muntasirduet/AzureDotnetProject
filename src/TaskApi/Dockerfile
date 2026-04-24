FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/TaskApi/TaskApi.csproj", "src/TaskApi/"]
RUN dotnet restore "src/TaskApi/TaskApi.csproj"

COPY . .
WORKDIR "/src/src/TaskApi"
RUN dotnet publish "TaskApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "TaskApi.dll"]
