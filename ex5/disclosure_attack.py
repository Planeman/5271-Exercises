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
            # User is sending in a round so add to observation vector
            for r_user in rec_rounds[index]:
                round_obs[getIndexForUser(r_user)] = 1.0/users_per_round

            observations = vectorOp(observations, round_obs, lambda x,y: x+y)
            total_messages += send_round.count(user)
        else:
            # User is *not* sending in ths round so add to the background traffic vector
            traffic = [0] * 260
            for r_user in rec_rounds[index]:
                traffic[getIndexForUser(r_user)] = 1.0/users_per_round

            b_traffic = vectorOp(b_traffic, traffic, lambda x,y: x+y)
            rounds_not_in += 1

    if rounds_not_in == int(num_rounds):
        return []

    b_traffic[:] = map(lambda traffic: traffic / float(rounds_not_in), b_traffic)

    # Avg # of messages sent per round by the target user
    user_avg_msgs = total_messages / float(num_rounds)
    b_traffic[:] = map(lambda traffic: (users_per_round - user_avg_msgs) * traffic, b_traffic)

    observations[:] = map(lambda obs: (obs * users_per_round), observations)
    observations[:] = map(lambda obs: obs / float(num_rounds), observations)

    user_recipient_prob = vectorOp(observations, traffic, lambda x,y: (x-y) / float(user_avg_msgs))

    friends = []
    top_two = findMaxTwo(user_recipient_prob)
    friends.append(getUserForIndex(top_two[0][0]))
    friends.append(getUserForIndex(top_two[1][0]))
    user_recipient_prob.sort()
    print("Highest % friends: {}".format(user_recipient_prob[-4:][::-1]))

    return friends

def vectorOp(v1, v2, func):
    new_vector = []
    for index,item in enumerate(v1):
        new_vector.append(func(item,v2[index]))

    return new_vector

def findMaxTwo(vector):
    top_index = top_value = -99999
    pen_index = pen_value = -99999

    for index,val in enumerate(vector):
        if val > top_value:
            pen_index = top_index
            pen_value = top_value
            top_index = index
            top_value = val
        elif val > pen_value:
            pen_index = index
            pen_value = val

    return ((top_index, top_value), (pen_index, pen_value))

def buildUserIndexes():
    lowest_char = ord(ascii_lowercase[0])
    for char in ascii_lowercase:
        for i in range(10):
            user = char + str(i)
            index = ((ord(char)*10) + i) - (lowest_char * 10)

            usersToIndex[user] = index
            indexToUsers[index] = user

def targetUserVector():
    target_user_names = []
    for char in ascii_lowercase:
        target_user_names.append("{}0".format(char))

    return target_user_names

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
    for index,user in enumerate(targetUserVector()):
        friends = findFriends(send_rounds, receive_rounds, user)
        print("{} -> {}".format(user, friends))


