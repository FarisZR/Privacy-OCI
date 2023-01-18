# Privacy-OCI
Automatically built container images for privacy services like Quetre and scribe.

**Bibliogram is Deprecated and no longer supported by the developer**

I use a Scheduled GitLab CI pipeline to check for updates, and if there are any new commits, it will start building images.

Quetre is built for X86-64, ARMv8, but scribe is only for AMD64, as nim lang image and their entire tooling stack needs to be rebuilt to support ARM.

## Docker Compose
```
version: '3.3'

services:
  srcibe:
    container_name: scribe
    image: fariszr/scribe:latest
    restart: always
    ports:
      - 127.0.0.1:8080:8080 #remember to always use a reverse proxy!
    environment:
      - APP_DOMAIN=scribe.example.com
      - LUCKY_ENV=production
      - PORT=8080 #SCRIBE_PORT doesn't do anything
      - SECRET_KEY_BASE=xxxx # lucky gen.secret_key
      - GITHUB_USERNAME=xxx # optional, only if you want to proxy gists
      - GITHUB_PERSONAL_ACCESS_TOKEN=xxx # optional, only if you want to proxy gists

  quetre:
    image: fariszr/quetre:latest
    container_name: quetre
    restart: always
    ports:
      - 127.0.0.1:3000:3000 #remember to always use a reverse proxy!
    # volumes:
    #  - ./quetre/.env:/app/.env:ro #optional

  # Deprecated
  bibliogram:
    image: fariszr/bibliogram:latest
    container_name: bibliogram
    restart: always
    ports:
      - 127.0.0.1:10407:10407 #remember to always use a reverse proxy!
    volumes:
      - ./bibliogram/config.js:/config/config.js:ro
```

## Image URLS
images are on Docker hub
https://hub.docker.com/r/fariszr/bibliogram (Deprecated)
https://hub.docker.com/r/fariszr/scribe (X86-64 only)
https://hub.docker.com/r/fariszr/quetre

## General GitLab CI notes

I need to use buildx to build multi-arch images,
more details from docker here
https://www.docker.com/blog/multi-arch-build-what-about-gitlab-ci/

### shell Rules

GitLab doesn't support using script generated Variables in rules,
it's a known issue for more than a year
https://gitlab.com/gitlab-org/gitlab/-/issues/235812

So what's the workaround?
As noted in the answer here, by someone i think is related to GitLab, you just put bash script to cancel the step,
depending on the value of the variable, basically a more inefficient rule.
https://stackoverflow.com/a/40538655

my workaround currently is this:
```
  before_script:
    - |
      if [ "$bibliogram_out_of_date" = true ]; then
        echo "bibliogram is out of date, build can continue"
      else
        echo "there is no new commit for bibliogram, no need for a new build" && exit 0
      fi
```

it will stop the job from executing if the value is not true, and the best thing is its a before_Script, so it executes before almost anything else.

### Build cache

Since GitLab runners seem to be slow, i included cache parameters to speed up the build a bit.
It currently only works with Buildx, Kaniko uses a cache repo and not a cache image.
```
docker buildx build --push --pull -t $CI_REGISTRY/$IMAGE_NAME:latest --cache-from $CI_REGISTRY/$CACHE_IMAGE:latest --cache-to $CI_REGISTRY/$CACHE_IMAGE:latest --file $DOCKER_FILE --platform linux/arm64 .
```

### updating build commit
the second part of this project is to update the build hash.
So the CI doesn't just endlessly build images.

So when everything is fine, the last step is create a commit with "skip-ci" to update the build hash for the program

I used the structure used here
https://devops.stackexchange.com/a/14240

and created an access token which only has write access to my repos, Per project access tokens seem to be a premium feature.


## Credit
thanks [Video-prize-ranch](https://codeberg.org/video-prize-ranch) for Quetre's [Dockerfile](https://codeberg.org/video-prize-ranch/images/src/commit/f3b17cb5925d50083b6321a3cf47c6520a1174d0/quetre/Dockerfile)