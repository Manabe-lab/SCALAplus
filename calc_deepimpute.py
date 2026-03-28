from deepimpute.multinet import MultiNet
import pandas as pd

data = pd.read_csv('temp.csv',index_col=0)

print('Working on {} cells and {} genes'.format(*data.shape))

# Using default parameters
multinet = MultiNet()

# Using all the data
multinet.fit(data,cell_subset=1,minVMR=0.5)

imputedData = multinet.predict(data)

imputedData.to_csv("imputed.csv")