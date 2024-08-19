class OperationResult {
  final bool isSuccess;
  final String message;
  final int? errorCode;

  OperationResult.success(this.message)
      : isSuccess = true,
        errorCode = null;

  OperationResult.error(this.message, [this.errorCode]) : isSuccess = false;
}
