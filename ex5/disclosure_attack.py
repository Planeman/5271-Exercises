import sys
from string import ascii_lowercase
from parse_rounds import parseRounds

numUsers = 260
num_rounds = 256
users_per_round = 32
usersToIndex = {}
indexToUsers = {}

def findFriends(send_rounds, rec_rounds, user):
    """
    Returns the friends which the given user has as determined from the
    data from send and receive rounds using an extended statistical
    disclosure attack.
    """
    b_traffic = [0] * 260  # u vector

    rounds_not_in = 0  # t'
    total_messages = 0  # m

    observations = [0.0] * 260 # o vector

    num_rounds = float(len(send_rounds))  # t

    for index,send_round in enumerate(send_rounds):
        round_obs = [0.0] * 260
        if user in send_round:
            for r_user in rec_rounds[index]:
                round_obs[getIndexForUser(r_user)] = 1.0/users_per_round

            observations = vectorOp(observations, round_obs, lambda x,y: x+y)
            total_messages += send_round.count(user)
        else:
            traffic = [0] * 260
            for r_user in rec_rounds[index]:
                traffic[getIndexForUser(r_user)] = 1.0/users_per_round

            b_traffic = vectorOp(b_traffic, traffic, lambda x,y: x+y)
            rounds_not_in += 1

    if rounds_not_in == int(num_rounds):
        return []

    b_traffic[:] = map(lambda traffic: traffic / float(rounds_not_in), b_traffic)

    user_avg_msgs = total_messages / float(num_rounds)
    b_traffic[:] = map(lambda traffic: (users_per_round - user_avg_msgs) * traffic, b_traffic)

    observations[:] = map(lambda obs: (obs * users_per_round), observations)
    observations[:] = map(lambda obs: obs / float(num_rounds), observations)

    user_recipient_prob = vectorOp(observations, traffic, lambda x,y: (x-y) / float(user_avg_msgs))
    print("User_recipient_prob = {}".format(user_recipient_prob))

    friends = []
    for index,val in enumerate(user_recipient_prob):
        if val > 0:
            friends.append(getUserForIndex(index))

    return friends

def vectorOp(v1, v2, func):
    new_vector = []
    for index,item in enumerate(v1):
        new_vector.append(func(item,v2[index]))

    return new_vector

def buildUserIndexes():
    lowest_char = ord(ascii_lowercase[0])
    for char in ascii_lowercase:
        for i in range(10):
            user = char + str(i)
            index = ((ord(char)*10) + i) - (lowest_char * 10)

            usersToIndex[user] = index
            indexToUsers[index] = user

def getIndexForUser(user):
    return usersToIndex[user]

def getUserForIndex(index):
    return indexToUsers[index]

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: {} [round file]".format(sys.argv[0]))
        sys.exit(1)

    buildUserIndexes()

    send_rounds, receive_rounds = parseRounds(sys.argv[1])

    #for user,index in usersToIndex.items():
    for user in ['a0','b0','e0']:
        friends = findFriends(send_rounds, receive_rounds, user)
        print("{} -> {}".format(user, friends))


