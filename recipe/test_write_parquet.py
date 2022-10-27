# taken from: https://github.com/conda-forge/arrow-cpp-feedstock/issues/567
# report of underlying bug: https://github.com/aws/aws-sdk-cpp/issues/1809

import numpy as np
import pandas as pd

def test_error():
    arr = np.random.randint(0, 100, size=(100, 4))
    df = pd.DataFrame(arr, columns=list('ABCD'))
    df.to_parquet('test.parquet')

if __name__ == '__main__':
    test_error()
