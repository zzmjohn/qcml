from scoop.expression import Constant
from scoop_geo_mean import geo_mean

def sqrt(x):    
    return geo_mean(x,Constant(1.0))

