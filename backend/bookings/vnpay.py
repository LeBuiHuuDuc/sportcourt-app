import hmac
import urllib.parse
import hashlib

class vnpay:
    def __init__(self):
        self.requestData = {}
        self.responseData = {}

    def get_payment_url(self, payment_url, secret_key):
        inputData = sorted(self.requestData.items())
        hasData = ''
        seq = 0
        for key, value in inputData:
            if seq == 1:
                hasData = (hasData + '&' + str(key) + '=' + urllib.parse.quote_plus(str(value)))
            else:
                seq = 1
                hasData = str(key) + '=' + urllib.parse.quote_plus(str(value))

        hashValue = hmac.new(
            secret_key.encode('utf-8'),
            hasData.encode('utf-8'),
            hashlib.sha512
        ).hexdigest()
        return f'{payment_url}?{hasData}&vnp_SecureHash={hashValue}'

    def validate_response(self, secret_key):
        vnp_SecureHash = self.responseData.get('vnp_SecureHash', '')
        if 'vnp_SecureHash' in self.responseData:
            del self.responseData['vnp_SecureHash']
        if 'vnp_SecureHashType' in self.responseData:
            del self.responseData['vnp_SecureHashType']

        inputData = sorted(self.responseData.items())
        hasData = ''
        seq = 0
        for key, val in inputData:
            if seq == 1:
                hasData = (
                        hasData + '&' + str(key) + '=' + urllib.parse.quote_plus(str(val))
                )
            else:
                seq = 1
                hasData = str(key) + '=' + urllib.parse.quote_plus(str(val))

        hashValue = hmac.new(
            secret_key.encode('utf-8'),
            hasData.encode('utf-8'),
            hashlib.sha512,
        ).hexdigest()

        return vnp_SecureHash == hashValue