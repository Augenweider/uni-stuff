#! /usr/bin/python3
"""Template for exercise 7.3.

Start with this file to work on exercise 7.3.
Don't modify the predefined function "shift_char".

References:
    * http://de.wikipedia.org/wiki/Polyalphabetische_Substitution

"""

from string import ascii_letters


def shift_char(char, shift, charset):
    """Perform casear shift on a single char.

    Args:
        char (str): the character to be shifted.
        shift (int): the shift performed on each single character
        charset (str): the character set used to define, which input
            characters should be shifted. All other characters remain
            unchanged.

    """
    index = (charset.index(char) + shift) % len(charset)
    return charset[index]


def caesar(text, shift, charset=ascii_letters):
    """Perfom a caesar shift on the input text and return the result.

    Args:
        text (str): the clear text to be encrypted.
        shift (int): the shift performed on each single character
        charset(list of str, optional): the character set used to define which
            input characters should be shifted. All other characters remain
            unchanged. Defaults to string.ascii_letters.

    Examples:

        >>> caesar("abc", -2)
        'YZa'
        >>> caesar("YZa", 2)
        'abc'

    """
    # prepare an empty list to be filled with the encrypted text
    encoded = []
    for char in text:
        new_char = char
        # only shift character, if it is member of the character set
        if char in charset:
            new_char = shift_char(char, shift, charset)
        encoded.append(new_char)
    # return a string representation of the resulting list
    return ''.join(encoded)


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Usage: " + sys.argv[0] +
              " <file-to-write-encrypted-stuff-into> <n>\n\n" +
              "where the text written to <stdin> will be \n" +
              "encrypted with the ceaser stream cipher, \n" +
              "(moved by <n> characters ..)\n" +
              "and written to the file.")
    else:
        try:
            f = open(sys.argv[1], 'x')
            ntext = ""
            try:
                while True:
                    ntext += "\n" + caesar(input(""), int(sys.argv[2]))
            except EOFError:
                pass  # End of input, now, write to file...
            except:
                raise

            f.write(ntext)
            f.close()
        except FileExistsError:
            print("File already exists! can't create to write into!")
            sys.exit(1)
        except:
            raise

        # encrypted = caesar("Egg, bacon, sausage and Spam", 3)
        # decrypted = caesar(encrypted, -3)
        # print(encrypted, decrypted, sep='\n')
