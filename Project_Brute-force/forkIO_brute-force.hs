import Prelude as P
import Data.Char
import Data.ByteString.Base16 as Base16
import qualified Crypto.Hash.SHA1 as SHA1 
import Data.ByteString.Char8 as BSC
import Control.Concurrent
import Control.Monad
--import Control.DeepSeq


bruteForce :: ByteString -> [[Char]] -> Maybe String
bruteForce x [] = Nothing
bruteForce x (word:ws)  | encode(SHA1.hash (BSC.pack word)) == x = Just word
                        | otherwise = bruteForce x ws


takeTask :: MVar [String] -> MVar [Char] -> ByteString -> Int -> IO ()
takeTask taskQueue resultContainer hashFind workerNumber = do
  maybeTask <- modifyMVar taskQueue
                 (\q -> return $ case q of
                                   [] -> ([], Nothing)
                                   xs -> (P.drop (125 * workerNumber) xs, Just (P.take (125 * workerNumber) xs)))   -- 4 ядра 500     8 ядер 1000
  case maybeTask of
    Nothing -> do
      let answ = "No such password"
      putMVar resultContainer answ
      return ()
    Just task -> do
      let rslt = bruteForce hashFind task
      case rslt of
        Nothing -> takeTask taskQueue resultContainer hashFind workerNumber
        Just answ -> do
          putMVar resultContainer ("Your password is: "++answ)
          return ()


main :: IO()
main = do
         --x <- P.getLine
         let x = "f888fa8a61ba9a53a45f040a4bbb8b2fc1f64444"
         let taskNumber = (P.length pull) ^ 5    -- общее кол-во вариантов пароля
         let hashFind = BSC.pack x
         workerNumber <- getNumCapabilities
         taskQueue <- newMVar allPasses
         resultContainer <- newEmptyMVar
         P.putStrLn $ "Processor cores: " ++ show workerNumber
         P.putStrLn "Searching password..."
         replicateM_ workerNumber (forkIO (takeTask taskQueue resultContainer hashFind workerNumber))
         out <- takeMVar resultContainer
         P.putStrLn out
         return()
   

allPasses = [a++b++c++d++e | a <- pull,b <- pull,c <- pull,d <- pull,e <- pull]
pull::[String]
pull = "" : (P.map show [0..9]) ++ (charsToStrings letters) ++ (charsToStrings(P.map toUpper letters))
letters = "abcdefghijklmnopqrstuvwxyz"
charsToStrings :: [Char] -> [String]
charsToStrings [x] = [[x]]
charsToStrings (x:xs) = [[x]] ++ (charsToStrings xs)
giveHash :: String -> ByteString
giveHash x = encode $ SHA1.hash (BSC.pack x)


--encode $ SHA1.hash (BSC.pack "1111")   
--da39a3ee5e6b4b0d3255bfef95601890afd80709        - ""
--17ba0791499db908433b80f37c5fbc89b870084b        - "11"
--6216f8a75fd5bb3d5f22b6f9958cdede3fc086c2        - "111"
--011c945f30ce2cbafc452f39840f025693339c42        - "1111"
--7b21848ac9af35be0ddb2d6b9fc3851934db8420        - "11111"      //  Total   time   35.922s  (  9.495s elapsed) - 4 ядра
--f888fa8a61ba9a53a45f040a4bbb8b2fc1f64444        - "ZZZZZ"      // Total   time  1219.672s  (324.559s elapsed) - 4 ядра
                                                           
