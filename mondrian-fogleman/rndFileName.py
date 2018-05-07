import random

# Function to generate random file names for generated images:
def random_string(length):
    charSet = '23456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ'
    return 'MFH_' + ''.join(random.choice(charSet) for i in range(length)) + '.hexplt'

fileNameStr = random_string(15)
print(fileNameStr)