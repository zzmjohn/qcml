from scoop.expression import isscalar

def mangle(d):
    return dict( ('_'+k,v) for k,v in d.iteritems() )

def ismultiply(k):
    return '*' in k
    
def istranspose(k):
    return '\'' in k

def issum(k):
    return 'sum' in k

def height_of(heights, lookup):
    v = 0
    for h in heights:
        v += h.row_value(lookup)
    return v


class Codegen(object):
    """Generic code generator object for optimization problems. Contains a
    dictionary of variables used in the optimization problem, cone constraints
    on them, and the objective function."""
    def __init__(self):
        # SOCP data structures (used for codegen)
        self.variables = {}     # these are used variables
        self.parameters = {}    # these are the used parameters
        self.cones = []
        self.obj = None
        
    def __str__(self):
        print str(self.variables)
        print str(self.cones)
        print str(self.obj)
        return ""
    
    def needed_variable_dims(self, list_of_used):
        d = set( k for k,v in self.variables.iteritems() if not isscalar(v.shape) )
        return d & set(list_of_used)
        
    def get_variable_sizes(self, defined):
        sizes = {}
                        
        for k,v in self.variables.iteritems():
            if isscalar(v.shape):
                sizes[k] = 1
            else:
                key = v.shape.rows.size
                sizes[k] = defined[key]
                
        return sizes
        

    # def zero_cones(self):
    #     """Builds A*x = b"""
    #     return filter(lambda e: e.size == 1, self.cones)
    #     
    # def second_order_cones(self):
    #     return filter(lambda e: e.size != 1, self.cones)
        
        