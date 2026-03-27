# 使用 .NET 8 SDK 作为构建镜像
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# 复制项目文件并还原依赖
COPY ["glxt.csproj", "./"]
RUN dotnet restore "glxt.csproj"

# 复制所有源代码
COPY . .

# 构建应用程序
RUN dotnet build "glxt.csproj" -c Release -o /app/build

# 发布应用程序
FROM build AS publish
RUN dotnet publish "glxt.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 使用 ASP.NET Core 运行时作为最终镜像
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# 复制发布的文件
COPY --from=publish /app/publish .

# 设置入口点
ENTRYPOINT ["dotnet", "glxt.dll"]
