# Netrewrite


## Install Picogen static website generator

```
python3 -m venv .venv &&
source .venv/bin/activate &&
pip install --upgrade pip &&
pip install picogen
```


## Generate the website

As per the [Picogen](https://pypi.org/project/picogen/) library use `picogen --generate` to generate a website into the `build` directory, using the default theme. Alternativelly run `python generate.py` to use one of its functions.


## Preview locally

```
python -m http.server --directory build --bind localhost
```