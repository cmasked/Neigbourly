"""Custom exception classes for structured error handling."""

from fastapi import HTTPException, status


class AppException(HTTPException):
    """Base application exception."""

    def __init__(self, status_code: int, detail: str, error_code: str = "GENERIC_ERROR"):
        super().__init__(status_code=status_code, detail=detail)
        self.error_code = error_code


class NotFoundError(AppException):
    def __init__(self, resource: str, resource_id: str = ""):
        detail = f"{resource} not found" + (f": {resource_id}" if resource_id else "")
        super().__init__(status.HTTP_404_NOT_FOUND, detail, "NOT_FOUND")


class DuplicateError(AppException):
    def __init__(self, detail: str = "Resource already exists"):
        super().__init__(status.HTTP_409_CONFLICT, detail, "DUPLICATE")


class ForbiddenError(AppException):
    def __init__(self, detail: str = "Access denied"):
        super().__init__(status.HTTP_403_FORBIDDEN, detail, "FORBIDDEN")


class UnauthorizedError(AppException):
    def __init__(self, detail: str = "Invalid credentials"):
        super().__init__(status.HTTP_401_UNAUTHORIZED, detail, "UNAUTHORIZED")


class BadRequestError(AppException):
    def __init__(self, detail: str = "Bad request"):
        super().__init__(status.HTTP_400_BAD_REQUEST, detail, "BAD_REQUEST")


class ConflictError(AppException):
    def __init__(self, detail: str = "Conflict detected"):
        super().__init__(status.HTTP_409_CONFLICT, detail, "CONFLICT")


class DoubleBookingError(ConflictError):
    def __init__(self):
        super().__init__("Item is not available for the requested dates")


class InvalidStateTransitionError(BadRequestError):
    def __init__(self, current: str, target: str):
        super().__init__(f"Cannot transition from '{current}' to '{target}'")


class PaymentError(AppException):
    def __init__(self, detail: str = "Payment processing failed"):
        super().__init__(status.HTTP_402_PAYMENT_REQUIRED, detail, "PAYMENT_ERROR")
