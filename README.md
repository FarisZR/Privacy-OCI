# Privacy-OCI
Automatically built container images for alternative frontends Quetre, scribe, Breezewiki and the Guest account branch of Nitter

**Bibliogram is Deprecated and no longer supported by the developer**

A Github action runs every hour to check for updates, and if there are any new commits, it will start building images.

## Supported architectures

### Breezewiki && Bibliogram
- AMD64

### Scribe & Nitter & Simplytranslate
- AMD64
- ARM64

### Quetre
- AMD64
- ARM64
- ARMv7

## Registries 
- `oci.fariszr.com` (Recommended, it's a redirect to [Quay.io](https://quay.io), and in the case of a new [rug pull](https://httptoolkit.com/blog/docker-image-registry-facade/), I can move to another host without changing the URL)
- GitHub packages (ghcr.io/FarisZR/)
- [docker hub](https://hub.docker.com/r/fariszr/)

## Docker Compose
[Here](docker-compose.yml)

## Credits
thanks [Video-prize-ranch](https://codeberg.org/video-prize-ranch) for Quetre's [Dockerfile](https://codeberg.org/video-prize-ranch/images/src/commit/f3b17cb5925d50083b6321a3cf47c6520a1174d0/quetre/Dockerfile)

## General GitLab CI notes (outdated)

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
