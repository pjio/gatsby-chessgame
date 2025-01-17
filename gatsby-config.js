module.exports = {
  siteMetadata: {
    title: `Chessgame Playground`,
    description: `This project is for personal learning purposes`,
    author: `@pjio`,
  },
  plugins: [
    `gatsby-plugin-react-helmet`,
    {
      resolve: `gatsby-source-filesystem`,
      options: {
        name: `images`,
        path: `${__dirname}/src/images`,
      },
    },
    `gatsby-transformer-sharp`,
    `gatsby-plugin-sharp`,
    {
      resolve: `gatsby-plugin-s3`,
      options: {
        bucketName: "chessgame.xubaso.com",
      },
    },
  ],
}
