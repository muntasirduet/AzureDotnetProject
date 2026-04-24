using TaskApi.Models;

namespace TaskApi.Tests;

public class UnitTest1
{
    [Fact]
    public void TaskItem_DefaultValues_AreExpected()
    {
        var item = new TaskItem
        {
            Title = "Learn Terraform"
        };

        Assert.Equal("Learn Terraform", item.Title);
        Assert.False(item.IsCompleted);
        Assert.True(item.CreatedAtUtc <= DateTimeOffset.UtcNow);
    }
}