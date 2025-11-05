def to_sheet_column(n: int) -> str:
    """
    Convert a positive integer to a column name for Excel or Spreadsheet format.

    Parameters
    ----------
    n : int
        The column number (1-indexed position).

    Returns
    -------
    str
        The column name.
    """
    if not isinstance(n, int) or n < 1:
        raise ValueError("n must be a positive integer")
    s = ""
    while n > 0:
        n -= 1
        s = chr(65 + (n % 26)) + s
        n //= 26
    return s
