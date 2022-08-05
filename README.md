# Privacy-OCI
Automatically built container images for privacy services like Bibliogram and scribe.

I use a Scheduled GitLab CI pipeline to check for updates, and if there any new commits, it will start building images.

Currently Bibliogram is built AMD64, and ARM64.
while scribe is only for AMD64, as nim lang image and their entire tooling stack needs to be rebuilt to support ARM.

## General GitLab CI notes

i need to use buildx to build multi-arch images,
more details from docker here
https://www.docker.com/blog/multi-arch-build-what-about-gitlab-ci/

### shell Rules

Gitlab doesnt support using script generated Variables in rules,
its a known issue for more than a year
https://gitlab.com/gitlab-org/gitlab/-/issues/235812

so whats the workaround?
as noted in the answer here, by someone i think is realted to gitlab, you just put bash script to cancel the step,
depending on the value of the variable, basically a more inefficent rule.
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

since Gitlab runners seem to be slow.
i included cache paramaters to speed up the build a bit.
it currently only works with Buildx, Kaniko uses a cache repo and not a cache image.
```
docker buildx build --push --pull -t $CI_REGISTRY/$IMAGE_NAME:latest --cache-from $CI_REGISTRY/$CACHE_IMAGE:latest --cache-to $CI_REGISTRY/$CACHE_IMAGE:latest --file $DOCKER_FILE --platform linux/arm64 .
```

### updating build commit
the secound part of this project is to update the build hash.
so the CI doesn't just endlessly build images.

so when everything is fine, the last step is create a commit with "skip-ci" to update the build hash for the program

i used the structure used here
https://devops.stackexchange.com/a/14240

and create an access token which only has write access to my repos, Per project access tokens seem to be a premium feature.
