--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Aeson  (decode)
import           Data.Monoid (mappend)
import           Data.Maybe  (fromJust)
import           Data.String (fromString)
import           Data.Time.Format (formatTime, defaultTimeLocale)
import           Data.Time.Clock (getCurrentTime)

import           Text.Pandoc.Highlighting (styleToCss)
import           Text.Pandoc.Options

import           Hakyll


--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
    {
        destinationDirectory = "docs"
    }

main :: IO ()
main = hakyllWith config $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "fonts/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*.theme" $ do
        route (setExtension "css")
        compile kdeSyntaxJsonToCss

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------

root :: String
root = "https://witchtype.github.io"

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

kdeSyntaxJsonToCss :: Compiler (Item String)
kdeSyntaxJsonToCss = fmap (styleToCss . fromJust . decode . fromString) <$> getResourceString