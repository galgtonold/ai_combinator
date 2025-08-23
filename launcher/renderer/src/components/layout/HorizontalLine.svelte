<script>
  // Props to customize the HR
  export let margin = "12px 0"; // Default is full width (no auto)
  export let width = "100%"; // Default to full width
</script>

<hr class="factorio-hr" style="margin: {margin}; width: {width};" />

<style>
  /* Using more specific selector to override Bulma */
  :global(hr.factorio-hr) {
    border-width: 3px 4px;
    border-color: #232223;
    border-style: solid;
    height: 0px;
    margin: 12px 0; /* Changed from auto to 0 for full width */
    width: 100%; /* Explicitly set width to 100% */
    border-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAAMCAMAAACz+6aNAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kTtIw1AUhv+miiIVBzuICEaoThbEF45ahSJUCLVCqw4mN31Bk4YkxcVRcC04+FisOrg46+rgKgiCDxBHJydFFynx3KTQIsYDl/vx3/P/3HsuINRKTLPaxgBNt81kPCamM6tixysCGEQIQ5iSmWXMSVICvvV1T91Ud1Ge5d/3Z3WrWYsBAZF4lhmmTbxBPL1pG5z3icOsIKvE58SjJl2Q+JHrisdvnPMuCzwzbKaS88RhYjHfwkoLs4KpEU8SR1RNp3wh7bHKeYuzVqqwxj35C0NZfWWZ67QGEMciliBBhIIKiijBRpR2nRQLSTqP+fj7Xb9ELoVcRTByLKAMDbLrB/+D37O1chPjXlIoBrS/OM7HMNCxC9SrjvN97Dj1EyD4DFzpTX+5Bsx8kl5tapEjoGcbuLhuasoecLkD9D0Zsim7UpCWkMsB72f0TRmg9xboWvPm1jjH6QOQolklboCDQ2AkT9nrPu/ubJ3bvz2N+f0As9tywbHNoQUAAAAJcEhZcwAACxMAAAsTAQCanBgAAAAHdElNRQfmAgcMERnVdktSAAAAGXRFWHRDb21tZW50AENyZWF0ZWQgd2l0aCBHSU1QV4EOFwAAAF1QTFRFAAAAAQABQAABIAABIB8AFgABEA8AEQABGgwAGxEAGA8AFQ0AGgwAFxAAERERFxcXIyIjIyMjJCMkJSQlNTQ1Pz4/RkVGSklKS0pLUFBQXVxdZGRkZ2dnaGho/v77qgZ5ogAAAA50Uk5TAAQECAgMEBAUHCAkKCzwtnm7AAAAAWJLR0QecgogKwAAAFhJREFUCNdtjjkOA0EMw0jbyf//G4yVYrfJwU4CdMA3ApW+xHFhQLsEiGsYyu5SSPaQbeh5qmpNsldqkoD6EgbAUpMEYCB5eDsJ+Nl8ssNK7vXdzZ+Hv7wBJcUwO5y9bxAAAAAASUVORK5CYII=") 6 8 repeat;
    border-image-outset: 0 2px;
    box-sizing: border-box;
    background-color: transparent; /* Override any Bulma background */
  }
</style>
