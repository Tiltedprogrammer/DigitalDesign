from scipy.sparse import csr_matrix
from scipy.sparse.csgraph import floyd_warshall
import random
import os



values = [i for i in range(1,11)]
values.append(10000)

def generate_graph():
    graph = [[0 for i in range(number_of_vertices)] for i in range(number_of_vertices)]
    for i in range(number_of_vertices):
        for j in range(number_of_vertices):
            if i == j:
                graph[i][j] = 0
            else:
                graph[i][j] = random.choice(values)
    return graph


def write_graphs_and_distances(g,filename):
    
    try:
        os.remove(filename)
    except OSError:
        pass
    with open(filename,'a') as f:
        
        for row in g:
            for element in row:
                f.write(str(element))
                f.write(" ")
            f.write("\n")
    try:
        os.remove(filename + "_dist")
    except OSError:
        pass
    with open(filename + "_dist","a") as f:
        csr_g = csr_matrix(g)
        distances = floyd_warshall(csgraph=csr_g, directed=True)
        for row in distances:
            for element in row:
                f.write(str(int(element)))
                f.write(" ")
            f.write("\n")


prefix = "7x7"
number_of_vertices = 7


for i in range(1,11):
    g = generate_graph()
    write_graphs_and_distances(g,f"{prefix}/input_graph{i}")