from flask import Flask, jsonify
from datetime import datetime

app = Flask (__name__)

@app.route('/time', methods=['Get'])

def get_time():
    # gets the current time in UTC
    current_time = datetime.now()
    # return current time in ISO format
    return jsonify({'current_time': current_time.strftime("%H:%M:%S")})

if __name__ == '__main__':
    app.run(host='0.0.0.0',port=8080)
