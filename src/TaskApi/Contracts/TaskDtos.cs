namespace TaskApi.Contracts;

public record CreateTaskRequest(string Title, string? Description);
public record UpdateTaskRequest(string Title, string? Description, bool IsCompleted);
