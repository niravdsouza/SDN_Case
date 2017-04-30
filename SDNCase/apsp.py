#https://jlmedina123.wordpress.com/2014/05/17/floyd-warshall-algorithm-in-python/
import ast
basepath = "/afs/unity.ncsu.edu/users/a/amuckad/SDN/SDNCase"

def floydwarshall(graph):
 
    # Initialize dist and pred:
    # copy graph into dist, but add infinite where there is
    # no edge, and 0 in the diagonal
    dist = {}
    pred = {}
    for u in graph:
        dist[u] = {}
        pred[u] = {}
        for v in graph:
            dist[u][v] = 1000
            pred[u][v] = -1
        dist[u][u] = 0
        for neighbor in graph[u]:
            dist[u][neighbor] = graph[u][neighbor]
            pred[u][neighbor] = u
 
    for t in graph:
        # given dist u to v, check if path u - t - v is shorter
        for u in graph:
            for v in graph:
                newdist = dist[u][t] + dist[t][v]
                if newdist < dist[u][v]:
                    dist[u][v] = newdist
                    pred[u][v] = pred[t][v] # route new path through t
 
    return dist, pred
 
 
def NextHop(src, dest):
	if pred[src][dest] == src:
		return dest
	return NextHop(src, pred[src][dest])

 
'''graph = {
0 : {2:1,1:1},
1 : {2:1,3:1,0:1},
2 : {0:1,1:1,3:1,4:1},
3 : {1:1,2:1,4:1},
4 : {2:1,3:1},
}'''

'''graph = {
0 : {1:7,2:11},
1 : {0:7,2:3,3:2},
2 : {0:11,1:3,3:4,4:5},
3 : {1:2,2:4,4:5},
4 : {2:5,3:5},
}'''

graphfile = open((basepath + "/reference/tempfiles/graph"),"r")
graph = ast.literal_eval(graphfile.read())
graphfile.close()

dist, pred = floydwarshall(graph)

'''print dist
print "-----------------"
print pred'''

#hostA = "hostA"
routerA = 0
#hostB = "192.168.1.2"
routerB = 4

'''for router in graph:
	print "#### %s ####" %router
	for to in graph:
		if router != to:
			interface = NextHop(router, to)
			print "%s - %s" % (to, interface)
	print "###########"
	print "\n"

print "-----------------------------------------"				
print "-----------------------------------------"'''

updatelistfile = open((basepath + "/reference/tempfiles/updatelist"),"w")
updatelistfile.write("from,to,port\n");
for router in graph:
	if router == routerA:
		interface = NextHop(router, routerB)
		print "%s,%s,%s" % (("router"+str(router)), "hostB", str(interface))
		updatelistfile.write("%s,%s,%s\n" % (("router"+str(router)), "hostB", str(interface)))
	elif router == routerB:
		interface = NextHop(router, routerA)
		print "%s,%s,%s" % (("router"+str(router)), "hostA", str(interface))
		updatelistfile.write("%s,%s,%s\n" % (("router"+str(router)), "hostA", str(interface)))
	else:
		interface = NextHop(router, routerA)
		print "%s,%s,%s" % (("router"+str(router)), "hostA", str(interface))
		updatelistfile.write("%s,%s,%s\n" % (("router"+str(router)), "hostA", str(interface)))
		interface = NextHop(router, routerB)
		print "%s,%s,%s" % (("router"+str(router)), "hostB", str(interface))
		updatelistfile.write("%s,%s,%s\n" % (("router"+str(router)), "hostB", str(interface)))
updatelistfile.close()


