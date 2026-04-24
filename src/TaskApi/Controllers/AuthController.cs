using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using TaskApi.Contracts;

namespace TaskApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(IConfiguration configuration) : ControllerBase
{
    [HttpPost("token")]
    public IActionResult GetToken([FromBody] AuthRequest request)
    {
        var configuredUser = configuration["DemoUser:Username"];
        var configuredPassword = configuration["DemoUser:Password"];

        if (request.Username != configuredUser || request.Password != configuredPassword)
        {
            return Unauthorized(new { message = "Invalid credentials." });
        }

        var secret = configuration["Jwt:Secret"] ?? throw new InvalidOperationException("Jwt:Secret missing.");
        var issuer = configuration["Jwt:Issuer"] ?? throw new InvalidOperationException("Jwt:Issuer missing.");
        var audience = configuration["Jwt:Audience"] ?? throw new InvalidOperationException("Jwt:Audience missing.");

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, request.Username),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials);

        return Ok(new { accessToken = new JwtSecurityTokenHandler().WriteToken(token) });
    }
}
