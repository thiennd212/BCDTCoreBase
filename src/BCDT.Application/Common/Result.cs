namespace BCDT.Application.Common;

public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Data { get; }
    public string Code { get; }
    public string Message { get; }

    private Result(bool isSuccess, T? data, string code, string message)
    {
        IsSuccess = isSuccess;
        Data = data;
        Code = code;
        Message = message;
    }

    public static Result<T> Ok(T data) => new(true, data, string.Empty, string.Empty);
    public static Result<T> Fail(string code, string message) => new(false, default, code, message);
}

public static class Result
{
    public static Result<T> Ok<T>(T data) => Result<T>.Ok(data);
    public static Result<T> Fail<T>(string code, string message) => Result<T>.Fail(code, message);
}
