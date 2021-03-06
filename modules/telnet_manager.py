"""
Helper class to manage telnet connections and provide
some useful commands to interact with telnet sessions
"""

from telnetlib import Telnet
from time import sleep
import logging


class TelnetManager(Telnet):
    """Class to manage the telnet connection which provides some useful additional methods"""

    def __init__(self, hostname=None, port=23, logger=None):
        Telnet.__init__(self, host=hostname, port=port)
        self.__host = hostname
        self.__log = logger
        if not self.__log:
            logging.basicConfig(format='%(asctime)s [%(levelname)s]: %(message)s',
                                datefmt='%Y-%m-%d %I:%M:%S', level=logging.INFO)
            self.__log = logging.getLogger('Telnet Session')
        self.__host = hostname
        self.endline = '\r\n'
        self.prompt = b'>'
        # telnet needs some time...
        sleep(1)
        self.read()

    def __del__(self):
        self.close()
        self.__log = None


    def read(self):
        """Read telnet response until next prompt"""
        self.read_until(self.prompt)

    def print(self, string, print_info=False):
        """remove telnet prompt from the string and output using logging.DEBUG level"""
        cleaned = string.rstrip(self.prompt).decode('ascii').strip()
        if not cleaned:
            cleaned = 'empty'
        if print_info:
            self.__log.info('Telnet response:\n' + cleaned)
        else:
            self.__log.debug('Telnet response: ' + cleaned)

    def send_command(self, cmd, print_info=False, return_response=False):
        """send telnet command and wait for response"""
        self.__log.debug('Send ' + cmd.rstrip(self.endline))
        if not cmd.endswith(self.endline):
            cmd += self.endline
        self.write(cmd.encode('ascii'))
        try:
            response = super().read_until(self.prompt)
        except EOFError:
            self.__log.error('Telnet connection closed while trying to send command '
                             + cmd.rstrip(self.endline))
            return False
        self.print(response, print_info)

        if return_response:
            return response.rstrip(self.prompt).decode('ascii').strip()
        return True
