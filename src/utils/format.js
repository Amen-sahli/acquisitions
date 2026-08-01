export const formatValidationError = (error) => {
  if (!error || !error.issues) {
    return 'Validation failed';
  }
  if (Array.isArray(error.issues)) {
    return error.issues.map((err) => err.message).join(', ');
  }

  return JSON.stringify(error);
};
